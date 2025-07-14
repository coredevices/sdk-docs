# Troubleshooting

This page contains fixes to known problems encountered from building the 
developer site, and how they were fixed. This may help you if you have 
the same problems.

## Nokogiri

**Error**

> An error occurred while installing nokogiri (1.6.7.2), and Bundler cannot continue.
> Make sure that `gem install nokogiri -v '1.6.7.2'` succeeds before bundling.

**Solution**

`gem install nokogiri -- --use-system-libraries`
