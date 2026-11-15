Feature: The navigation and the images of the site
  As the owner of the site
  I want the menu to lead to the pages of the site and the images to be optimized
  So that a visitor finds the pages and the pages load without a jump

  # The links are asserted by their text and path: the menu also links to other sites, and the
  # suite depends on this site only.

  Scenario: The navigation has the pages of the site
    Given I am on the homepage
    Then I should see a navigation menu with the following links:
      | text  | path   |
      | Home  | /      |
      | About | /about |

  Scenario: The list of posts shows optimized images
    Given I am on "/blog/"
    Then the response status code should be 200
    And I should see an optimized image
    And every optimized image should have a width and a height
    And every optimized image should load lazily
    And all optimized images should be loaded
