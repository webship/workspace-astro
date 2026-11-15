Feature: The build wrote a sitemap and a feed
  As the owner of the site
  I want the sitemap and the feed to list the pages and the posts of the site
  So that search engines and readers find what was published

  Scenario: The sitemap lists the pages and the posts, and nothing else
    Given I am on the homepage
    Then the sitemap should list "/"
    And the sitemap should list "/about/"
    And the sitemap should list "/blog/first-post/"
    And the sitemap should not list "/this-page-does-not-exist/"

  Scenario: The feed is valid and lists a post
    Given I am on the homepage
    Then the RSS feed should be valid
    And the RSS feed at "/rss.xml" should be valid
    And the RSS feed should list "First post"
