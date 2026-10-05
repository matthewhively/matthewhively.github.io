---
name: ruby-development
description: >-
  Use whenever discussing development, debugging, reviewing, or navigating
  Ruby and Rails applications. Includes rbenv, application code,
  and repository path resolution in vizmule or vizmule_rails, sublime or sublimemanga, pb or productbible,
  and shopping_cart_engine.
---

When using this skill, state “Using skill: ruby-development”
before proceeding. Announce once per task, not on every response.

Before performing this workflow, read and apply
../../references/common.md

All of our rubies are installed using rbenv.
Assume Rails version 5.2 and Ruby 2.7.8 unless otherwise stated.

ADDITIONAL GITHUB RULES

Many of our repositories are for Ruby-on-Rails applications.
Therefore assume all standard Rails paths are relative to the "rails application root" instead of the "repository root" unless explicitly stated otherwise.

Repository Root Mapping (STRICT)
Use the following repo to "rails application root" mappings:
- vizmule_rails → railsapp/
- sublime → railsapp/
- pb → railsapp/
- shopping_cart_engine → shopping_cart_engine/
These mappings must be applied automatically when resolving file paths.
Do not search for the "rails application root" directory if it is defined here.
If a repository is not listed in Repository Root Mapping (STRICT), do not guess its application root. Use the user-provided path as written, or search only if needed.

When the user refers to a directory such as lib/constraints or app/models, interpret the request as applying to files within the resolved resolved directory rails application root directory

If multiple files in a repository could potentially match a given path, prioritize the path found within the "rails application root"
EXCEPTION: When the path already contains another top-level directory such as `refinery/` or `upgrade/` (etc)

