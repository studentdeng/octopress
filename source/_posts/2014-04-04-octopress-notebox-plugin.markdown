---
layout: post
title: "octopress notebox plugin"
date: 2014-04-04 16:48
comments: true
categories: [Plugin, ruby]
---
用了这么长时间的[octopress](http://octopress.org/)总该扩展一点点事情了，在Blogging的时候，总有一些信息是需要被特殊标记的，但是我并不喜欢简单的加粗或是斜体。类似的东西在Apple Document中有很多 

{% imgcap /images/octopress_notebox_plugin1.png Apple Document Note sample%}  

这里我就把这个功能照搬到octopress中了。

1.在*plugins*目录创建一个notebox.rb 

{% codeblock lang:Ruby %}
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
{% endcodeblock %}

2.在*sass/custom*中的文件*_stype.scss*的最后添加下面的代码

{% codeblock lang:css %}
.notebox {
  border:1px;
  border-style: solid;
  border-color: #5088C5;
  background-color:#fff;
  margin:.75em 0 1.5em;
  padding:.75em .667em .75em .750em;
  text-align:left;
}
{% endcodeblock %}

3.markdown的语法（*因为格式问题写成了％，需要替换成%*）

	{％ notebox ％}
	the text to note
	{％ endnotebox ％}

效果

{% notebox %}
text
{% endnotebox %}