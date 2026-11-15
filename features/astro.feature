Feature: The Astro plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the Astro builder, each
  AI folder lists the items of its kind the plugin ships, and the Plugins page lists the plugin
  with its steps.

  Scenario: The plugin is listed on the Plugins page
    Given I am on "/settings/plugins"
     Then I should see "Astro"
      And I should see "@webship.co/workspace-astro"

  Scenario: A sites folder offers the Astro builder
    Given I am on "/dev"
     Then "option[value='cmd-astro-project.sh']" should be attached

  Scenario: The AI Agents folder lists the agents the plugin ships
    Given I am on "/ai-agents"
     Then I should see "astro-site-builder"
      And I should see "astro-tester"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills"
     Then I should see "astro-scenarios"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands"
     Then I should see "astro-test"

  Scenario: The AI Prompts folder lists the prompt the plugin ships
    Given I am on "/ai-prompts"
     Then I should see "astro-build-and-test"
