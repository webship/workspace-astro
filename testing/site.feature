Feature: The built site answers
  As the owner of the site
  I want the production build to be served and complete
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.
  # The site is static: it has no accounts, so no scenario logs in. The suite runs against the
  # production build that is served at the address of the project; build again after a change
  # (cmd-tools-astro-cli.sh <project> --build). The scenarios about the navigation, the sitemap
  # and the feed fit the template the builder uses by default; a site from another template, or
  # one whose menu you changed, needs its own. No scenario follows a link to another site: the
  # suite depends on this site only.

  @critical
  Scenario: The front page is served from the production build
    Given I am an anonymous user
    And I am on the homepage
    Then the response status code should be 200
    And the site should be a production build

  @critical
  Scenario: The navigation has the pages of the site
    Given I am on the homepage
    Then I should see a navigation menu with the following links:
      | text  | path   |
      | Home  | /      |
      | About | /about |

  Scenario: The build wrote a sitemap that lists the front page
    Given I am on the homepage
    Then the sitemap should list "/"

  Scenario: The build wrote a feed
    Given I am on the homepage
    Then the RSS feed should be valid

  Scenario: An address with no page answers 404
    When I go to "/this-page-does-not-exist/"
    Then the response status code should be 404
