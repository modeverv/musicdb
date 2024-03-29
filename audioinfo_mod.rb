require "iconv"
require "stringio"

require "mp3info"
require "ogginfo"
require "wmainfo"
require "mp4info"
require "flacinfo"
require "apetag"

$: << File.expand_path(File.dirname(__FILE__))

require "audioinfo/mpcinfo"

class AudioInfoError < Exception ; end

class AudioInfo
  MUSICBRAINZ_FIELDS = { 
    "trmid" 	=> "TRM Id",
    "artistid" 	=> "Artist Id",
    "albumid" 	=> "Album Id",
    "albumtype"	=> "Album Type", 
    "albumstatus" => "Album Status",
    "albumartistid" => "Album Artist Id",
    "sortname" => "Sort Name",
    "trackid" => "Track Id"
  }

  SUPPORTED_EXTENSIONS = %w{mp3 ogg mpc wma mp4 aac m4a flac}

  VERSION = "0.1.7"

  attr_reader :path, :extension, :musicbrainz_infos, :tracknum, :bitrate, :vbr
  attr_reader :artist, :album, :title, :length, :date
attr_reader :genre  # mod
  # "block version" of #new()
  def self.open(*args)
    audio_info = self.new(*args)
    ret = nil
    if block_given?
      begin
        ret = yield(audio_info)
      ensure
        audio_info.close
      end
    else
      ret = audio_info
    end
    ret
  end

  # open the file with path +fn+ and convert all tags from/to specified +encoding+
  def initialize(filename, encoding = 'utf-8')
    raise(AudioInfoError, "path is nil") if filename.nil?
    @path = filename
    ext = File.extname(@path)
    raise(AudioInfoError, "cannot find extension") if ext.empty?
    @extension = ext[1..-1].downcase
    @musicbrainz_infos = {}
    @encoding = encoding

    begin
      case @extension
	when 'mp3'
	  @info = Mp3Info.new(filename, :encoding => @encoding)
	  default_tag_fill
	  #"TXXX"=>
	  #["MusicBrainz TRM Id\000",
	  #"MusicBrainz Artist Id\000aba64937-3334-4c65-90a1-4e6b9d4d7ada",
	  #"MusicBrainz Album Id\000e1a223c1-cbc2-427f-a192-5d22fefd7c4c",
	  #"MusicBrainz Album Type\000album",
	  #"MusicBrainz Album Status\000official",
	  #"MusicBrainz Album Artist Id\000"]
          
	  if (arr = @info.tag2["TXXX"]).is_a?(Array)
	    fields = MUSICBRAINZ_FIELDS.invert
	    arr.each do |val|
	      if val =~ /^MusicBrainz (.+)\000(.*)$/
		short_name = fields[$1]
	        @musicbrainz_infos[short_name] = $2
	      end
	    end
	  end
          @bitrate = @info.bitrate
	  i = @info.tag.tracknum
	  @tracknum = (i.is_a?(Array) ? i.last : i).to_i
	  @length = @info.length.to_i
	  @date = @info.tag["date"]
        @vbr = @info.vbr
        @genre = @info.tag["genre_s"] || "unknown"
	  @info.close

	when 'ogg'
	  @info = OggInfo.new(filename, @encoding)
	  default_fill_musicbrainz_fields
	  default_tag_fill
          @bitrate = @info.bitrate/1000
          @tracknum = @info.tag.tracknumber.to_i
	  @length = @info.length.to_i
	  @date = @info.tag["date"]
        @vbr = true
        @genre = @info.tag["genre"]||@info.tag["genre_s"] ||@info.tag["GENR"] || @info.tag["GENRE"]
	  @info.close
	  
	when 'mpc'
          fill_ape_tag(filename)

	  mpc_info = MpcInfo.new(filename)
          @bitrate = mpc_info.infos['bitrate']/1000
	  @length = mpc_info.infos['length']

        when 'ape'
	  fill_ape_tag(filename)

        when 'wma'
	  @info = WmaInfo.new(filename, :encoding => @encoding)
	  @artist = @info.tags["Author"]
	  @album = @info.tags["AlbumTitle"]
	  @title = @info.tags["Title"]
	  @tracknum = @info.tags["TrackNumber"].to_i
	  @date = @info.tags["Year"]
	  @bitrate = @info.info["bitrate"]
        @length = @info.info["playtime_seconds"]

        @genre = ""
        
	  MUSICBRAINZ_FIELDS.each do |key, original_key|
	    @musicbrainz_infos[key] = 
              @info.info["MusicBrainz/" + original_key.tr(" ", "")] ||
              @info.info["MusicBrainz/" + original_key]
	  end
          
	when 'aac', 'mp4', 'm4a'
	  @info = MP4Info.open(filename)
	  @artist = @info.ART
	  @album = @info.ALB
	  @title = @info.NAM
	  @tracknum = ( t = @info.TRKN ) ? t.first : 0
	  @date = @info.DAY
	  @bitrate = @info.BITRATE
        @length = @info.SECS
        @genre = @info.GEN || @info.GNRE || "unknown"
        
	  mapping = MUSICBRAINZ_FIELDS.invert

	  faad_info(filename).match(/^MusicBrainz (.+)$/) do
	    name, value = $1.split(/: /, 2)
	    key = mapping[name]
	    @musicbrainz_infos[key] = value
	  end
	
	when 'flac'
	  @info = FlacInfo.new(filename)
          tags = convert_tags_encoding(@info.tags, "UTF-8")
	  @artist = tags["ARTIST"] || tags["artist"]
	  @album = tags["ALBUM"] || tags["album"]
	  @title = tags["TITLE"] || tags["title"]
	  @tracknum = (tags["TRACKNUMBER"]||tags["tracknumber"]).to_i
	  @date = tags["DATE"]||tags["date"]
        @length = @info.streaminfo["total_samples"] / @info.streaminfo["samplerate"].to_f

        @genre = tags["GENRE"] || tags["GNRE"] || "unknown"

        
	  @bitrate = File.size(filename).to_f*8/@length/1024
          tags.each do |tagname, tagvalue|
            next unless tagname =~ /^musicbrainz_(.+)$/
            @musicbrainz_infos[$1] = tags[tagname]
          end
          @musicbrainz_infos["trmid"] = tags["musicip_puid"]
	  #default_fill_musicbrainz_fields

	else
	  raise(AudioInfoError, "unsupported extension '.#{@extension}'")
      end

      if @tracknum == 0
        @tracknum = nil
      end

      @musicbrainz_infos.delete_if { |k, v| v.nil? }
      @hash = { "artist" => @artist,
	"album"  => @album,
	"title"  => @title,
	"tracknum" => @tracknum,
	"date" => @date,
	"length" => @length,
        "bitrate" => @bitrate,
        "genre" => @genre,
      }

    rescue Exception, Mp3InfoError, OggInfoError, ApeTagError => e
      raise AudioInfoError, e.to_s, e.backtrace
    end

    @needs_commit = false

  end

  # set the title of the file
  def title=(v)
    if @title != v
      @needs_commit = true
      @title = v
    end
  end

  # set the artist of the file
  def artist=(v)
    if @artist != v
      @needs_commit = true
      @artist = v
    end
  end

  # set the album of the file
  def album=(v)
    if @album != v
      @needs_commit = true
      @album = v
    end
  end

  # set the track number of the file
  def tracknum=(v)
    v = v.to_i
    if @tracknum != v
      @needs_commit = true
      @tracknum = v
    end
  end

  # hash-like access to tag
  def [](key)
    @hash[key]
  end

  # convert tags to hash
  def to_h
    @hash
  end

  # close the file and commits changes to disk
  def close
    if @needs_commit
      case @info
        when Mp3Info
	  Mp3Info.open(@path, :encoding => @encoding) do |info|
	    info.tag.artist = @artist
	    info.tag.title = @title
	    info.tag.album = @album
	    info.tag.tracknum = @tracknum
	  end
	when OggInfo
	  OggInfo.open(@path, @encoding) do |ogg|
            { "artist" => @artist,
	      "album"  => @album,
	      "title"  => @title,
              "tracknumber" => @tracknum}.each do |k,v|
	      ogg.tag[k] = v.to_s
	    end
	  end

        when ApeTag
          ape = ApeTag.new(@path)
          ape.update do |fields|
            fields["Artist"] = @artist
            fields["Album"] = @album
            fields["Title"] = @title
            fields["Track"] = @tracknum.to_s
          end
	else
	  raise(AudioInfoError, "implement me")
      end
      
    end
    @needs_commit
  end
=begin
   {"musicbrainz_albumstatus"=>"official",
    "artist"=>"Jill Scott",
    "replaygain_track_gain"=>"-3.29 dB",
    "tracknumber"=>"1",
    "title"=>"A long walk (A touch of Jazz Mix)..Jazzanova Love Beats...",
    "musicbrainz_sortname"=>"Scott, Jill",
    "musicbrainz_artistid"=>"b1fb6a18-1626-4011-80fb-eaf83dfebcb6",
    "musicbrainz_albumid"=>"cb2ad8c7-4a02-4e46-ae9a-c7c2463c7235",
    "replaygain_track_peak"=>"0.82040048",
    "musicbrainz_albumtype"=>"compilation",
    "album"=>"...Mixing (Jazzanova)",
    "musicbrainz_trmid"=>"1ecec0a6-c7c3-4179-abea-ef12dabc7cbd",
    "musicbrainz_trackid"=>"0a368e63-dddf-441f-849c-ca23f9cb2d49",
    "musicbrainz_albumartistid"=>"89ad4ac3-39f7-470e-963a-56509c546377"}>
=end

  # check if the file is correctly tagged by MusicBrainz
  def mb_tagged?
    ! @musicbrainz_infos.empty?
  end

  private 

  def sanitize(input)
    s = input.is_a?(Array) ? input.first : input
    s.gsub("\000", "")
  end

  def default_fill_musicbrainz_fields(tags = @info.tag)
    MUSICBRAINZ_FIELDS.keys.each do |field|
      val = tags["musicbrainz_#{field}"]
      @musicbrainz_infos[field] = val if val
    end
  end

  def default_tag_fill(tags = @info.tag)
    %w{artist album title}.each do |v|
      instance_variable_set( "@#{v}".to_sym, sanitize(tags[v].to_s) )
    end
  end

  def fill_ape_tag(filename)
    begin
      @info = ApeTag.new(filename)
      #tags = convert_tags_encoding(@info.fields, "UTF-8")
      tags = @info.fields.inject({}) do |hash, (k, v)|
        hash[k.downcase] = v ? v.first : nil
        hash
      end
      default_fill_musicbrainz_fields(tags)
      default_tag_fill(tags)

      @date = tags["year"]
      @tracknum = tags['track'].to_i
    rescue ApeTagError
    end
  end

  def convert_tags_encoding(tags_orig, from_encoding)
    tags = {}
    Iconv.open(@encoding, from_encoding) do |ic|
      tags_orig.inject(tags) do |hash, (k, v)| 
        if v.is_a?(String)
          hash[ic.iconv(k)] = ic.iconv(v)
        end
        hash
      end
    end
    tags
  end

  def faad_info(file)
    stdout, stdout_w = IO.pipe
    stderr, stderr_w = IO.pipe

    fork do
      stdout.close
      stderr.close
      STDOUT.reopen(stdout_w)
      STDERR.reopen(stderr_w)
      exec 'faad', '-i', file
    end

    stdout_w.close
    stderr_w.close
    pid, status = Process.wait2

    out = stdout.read.chomp
    stdout.close
    err = stderr.read.chomp
    stderr.close

    # Return the stderr because faad prints info on that fd...
    status.exitstatus.zero? ? err : ''
  end
end
