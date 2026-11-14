Feature: The Astro plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the Astro builder, the
  AI Agents folder lists the Astro agents, and the Plugins page lists the plugin with its steps.

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
