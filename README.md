# Redmine AI Writer

AI-powered content generation for Redmine issues – write marketing posts, release notes, or any long-form text with one click.

## Key Features

* **GPT-based content generation** – uses OpenAI Chat API (GPT-3.5 / GPT-4) to create high-quality text.
* **Prompt templates** – store reusable templates in a custom field on the **parent issue**; placeholders are auto-replaced by the child issue's data.
* **Automatic prompt build** – when you create a child issue the plugin generates the prompt from its parent template; when you clear the prompt and save, it is regenerated.
* **One-click generation & apply** – generate, review, edit, then apply the text to the issue description.
* **Permissions & project module** – enable the feature per project and per role.
* **I18n ready** – English and Vietnamese locales included; add more in `config/locales/`.

## Requirements

* Redmine ≥ 5.0 (Rails 6.1)
* Ruby ≥ 3.0
* An OpenAI API key

## Installation

```bash
cd redmine/plugins
# clone or copy the plugin
git clone https://github.com/your-org/redmine_ai_writer.git

# install dependencies from Redmine root
bundle install

# (optional) migrate if plugin adds DB tables
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

Restart Redmine (Puma/Passenger/Thin) to load the plugin.

## Configuration

1. Navigate to **Administration → Plugins → Redmine AI Writer → Configure**.
2. Fill in:
   * **OpenAI API Key** – your secret key.
   * **Prompt Custom Field ID** – *Text* custom field on issues that will store the generated prompt.
   * **Prompt Template Custom Field ID** – *Text* custom field on issues that stores the template (usually only added to the tracker of parent tasks).
   * **System prompt** – high-level instruction sent to the model (e.g. *"You are a helpful marketing copywriter…"*).
3. Ensure both custom fields are **enabled for the trackers** you need.
4. Grant the **`Use AI Writer`** permission to the desired roles.

### Prompt Template Example

```
Create an engaging Facebook post about: {issue_title}

Project: {project_name}
Description:
"""{project_desciption}"""
```

Placeholders:
* `{issue_title}` – current issue subject.
* `{project_name}` – project name.
* `{project_desciption}` – cleaned project description (HTML removed, line breaks preserved).

## Usage

1. Open (or create) a **child issue** under a parent that contains a *Prompt template*.
2. The *Prompt* field is auto-filled – edit it if necessary.
3. Click **Generate with AI**; wait for the response.
4. Review / edit the result, then **Apply** – the issue description is updated.

If you clear the *Prompt* field and save, the plugin regenerates it immediately from the parent template.

## Development / Tests

```bash
cd plugins/redmine_ai_writer
bundle exec rake redmine:plugins:test RAILS_ENV=test
```

## Licence

MIT – see `LICENSE` file.

## Acknowledgements

* [Redmine](https://www.redmine.org/)
* [OpenAI Ruby SDK](https://github.com/alexrudall/ruby-openai)

## Contributing

PRs and issue reports are welcome! Please open an issue first to discuss major changes.
