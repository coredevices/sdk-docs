<h3>{{ title }}</h3>
<ul>
  {{#each results}}
  <li class="quicksearch__result">
    <a href="{{ url }}">{{ title }}</a>
    <p class="quicksearch__section">{{{ section }}}</p>
    <p class="quicksearch__summary">{{{ summary }}}</p>
  </li>
{{/each}}
</ul>
