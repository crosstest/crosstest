module Crosstest
  module Code2Doc
    # This class was extracted from the [Rocco](http://rtomayko.github.com/rocco/) project
    # which was in turn based on the [Docco](http://jashkenas.github.com/docco/).
    module CommentStyles
      class UnknownStyleError < StandardError
        attr_accessor :extension

        def initialize(extension)
          @extension = extension
        end
      end

      def self.infer(extension)
        extension.tr! '.', ''
        return extension, COMMENT_STYLES[extension] if COMMENT_STYLES.key? extension

        COMMENT_STYLES.each do | _style_name, style |
          return extension, style if style[:extensions].include? extension
        end

        fail UnknownStyleError, extension
      end

      C_STYLE_COMMENTS = {
        single: '//',
        multi: { start: '/**', middle: '*', end: '*/' },
        heredoc: nil,
        extensions: %w(c cpp cs java js php scala go)
      }

      COMMENT_STYLES  = {
        'bash'          =>  { single: '#', multi: nil, extensions: %w(sh) },
        'c'             =>  C_STYLE_COMMENTS,
        'coffee-script' =>  {
          single: '#',
          multi: { start: '###', middle: nil, end: '###' },
          heredoc: nil,
          extensions: %w(coffee)
        },
        'cpp' =>  C_STYLE_COMMENTS,
        'csharp' => C_STYLE_COMMENTS,
        'css'           =>  {
          single: nil,
          multi: { start: '/**', middle: '*', end: '*/' },
          heredoc: nil,
          extensions: %w(css scss sass)
        },
        'html'           =>  {
          single: nil,
          multi: { start: '<!--', middle: nil, end: '-->' },
          heredoc: nil,
          extensions: %w(html htm)
        },
        'java'          =>  C_STYLE_COMMENTS,
        'js'            =>  C_STYLE_COMMENTS,
        'lua'           =>  {
          single: '--',
          multi: nil,
          heredoc: nil,
          extensions: %w(lua)
        },
        'php' => C_STYLE_COMMENTS,
        'python'        =>  {
          single: '#',
          multi: { start: '"""', middle: nil, end: '"""' },
          heredoc: nil,
          extensions: %w(py)
        },
        'rb'            =>  {
          single: '#',
          multi: { start: '=begin', middle: nil, end: '=end', idiomatic: false },
          heredoc: '<<-',
          extensions: %w(rb)
        },
        'scala'         =>  C_STYLE_COMMENTS,
        'scheme'        =>  { single: ';;',  multi: nil, heredoc: nil, extensions: %w(scheme) },
        'yaml'        =>  { single: '#',  multi: nil, heredoc: nil, extensions: %w(yaml) },
        'xml'           =>  {
          single: nil,
          multi: { start: '<!--', middle: nil, end: '-->' },
          heredoc: nil,
          extensions: %w(xml xsl xslt)
        }
      }
    end
  end
end
