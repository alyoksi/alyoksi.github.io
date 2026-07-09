---
layout: default
title: other/ 
permalink: /other/
---

# $ show /home/user/other

{% assign newbie = site.other_resources | where: "level", "newbie" %}
{% assign advanced = site.other_resources | where: "level", "advanced" %}

## Basic

{% if newbie.size > 0 %}
{% for item in newbie %}
-**[{{ item.title }}]({{ item.link }})** ({{ item.type }}){% if item.description and item.description != "" %} — {{ item.description }}{% endif %}
{% endfor %}
{% else %}
Nothing here yet.
{% endif %}

## Advanced

{% if advanced.size > 0 %}
{% for item in advanced %}
-**[{{ item.title }}]({{ item.link }})** ({{ item.type }}){% if item.description and item.description != "" %} — {{ item.description }}{% endif %}
{% endfor %}
{% else %}
Nothing here yet.
{% endif %}