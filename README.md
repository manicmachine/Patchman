# Patchman 

![patchman_screenshot](https://github.com/manicmachine/Patchman/assets/11064500/4bc25703-7d9c-42c1-b65f-a5ff6bd57135)

Patchman is a macOS Swift application for simplifying maintaining patch policies in the Jamf Pro Server (JPS). It will query the JPS for all configured patch titles, their respective patch policies, and the currently available patch definitions. It will then display those patch titles whose most current patch policy is behind the latest patch definition for their respective applications. You can then select records from the list and remove them as you update them - acting as todo list for maintaining patch policies.

**NOTE**: Your JPS URL and User are both stored within your application preferences, whereas your password is securely stored within your local keychain.
