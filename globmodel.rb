# -*- coding:utf-8  -*-
class GlobServerFiles
  def self.data(args = {})
    @folders = args[:folders] ||= [
#                                   "/var/smb/sdb1/music/iTunesMac/BAIDOKU",
#                                   "/var/smb/sdb1/music/iTunes1",
#                                   "/var/smb/sdb1/music/iTunes2",
#                                   "/var/smb/sdb1/music/iTunes3",
                                   "/var/smb/sdb1/music/iTunes2011",
#                                   "/var/smb/sdb1/music/iTunesMac",
                                   "/var/smb/sdb1/music/iTunesLossless",
                                   "/var/smb/sdb1/video2/作成",
                                  ]
    @ext = args[:ext] ||= [
                           'MP3',
                           'M4A',
                           'WAV',
                           'MKA',
                           'APE',
                           'FLAC',
                           'WMA',
                           'OGG',                          
                          ]
    [@folders,@ext]
  end

  def self.glob
    @files = []
    @filders,@ext = GlobServerFiles.data

    @folders.each do |p|
      @ext.each do |e|
        Dir.glob("#{p}/**/*.#{e}") do |element|
          @files << { 'path' => element }
        end
        Dir.glob("#{p}/**/*.#{e.downcase}") do |element|
          @files << { 'path' => element }
        end
      end
    end
    
    return @files
  end
end
