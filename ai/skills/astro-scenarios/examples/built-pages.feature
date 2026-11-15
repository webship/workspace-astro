Feature: The pages of the production build
  As the owner of the site
  I want every page to be served from the production build, as plain pages
  So that a build that came out broken, or a page that started to ship scripts, is caught by the suite

  # The titles and the addresses are the ones of the template the builder uses by default:
  # change them to the pages of the site.

  Scenario: The front page is a production build that ships no script
    Given I am an anonymous user
    And I am on the homepage
    Then the response status code should be 200
    And the site should be a production build
    And the page should not ship JavaScript
    And the page should have scoped styles
    And the page title should end with "Astro Blog"

  Scenario: A page and a post have their own addresses
    Given I am on "/about/"
    Then the response status code should be 200
    And I should see "About Me"
    When I go to "/blog/first-post/"
    Then the response status code should be 200
    And the page title should end with "First post"

  Scenario: The site has no islands, no view transitions and no route announcer
    Given I am on the homepage
    Then the page should not have any islands
    And the page should not use view transitions
    And the page should not have a route announcer

  Scenario: An address with no page answers 404
    When I go to "/this-page-does-not-exist/"
    Then the response status code should be 404
