module Jekyll
  class Notebox < Liquid::Block

    def initialize(name, id, tokens)
      super
      @id = id
    end

    def render(context)
      stressText = paragraphize(super)

      source = "<div class='notebox'><p><strong>Note: </strong>#{stressText}</p></div>"
      source

    end

    def paragraphize(input)
      "#{input.lstrip.rstrip.gsub(/\n\n/, '</p><p>').gsub(/\n/, '<br/>')}"
    end

  end
end

Liquid::Template.register_tag('notebox', Jekyll::Notebox)