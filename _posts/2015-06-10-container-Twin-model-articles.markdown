---
layout: post
title: "Collected articles on twin modeling in umx"

comments: true
categories: container
---

<a name="top"></a>
Articles on twin modeling in `umx` are collected here.


<ul>
  {% for post in site.categories.twin %}
	{% if post.url %}
  <li><a href="{{ post.url }}">{{ post.title }}</a></li>
	{% endif %}
  {% endfor %}
</ul>
