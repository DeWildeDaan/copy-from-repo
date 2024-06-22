# Copy Files from Source Repo Action

This GitHub Action copies files from a specified source repository to the repository where the action is running.

This action can be used to automate file synchronization between repositories, ensuring that the latest files from the source repository are always available in the current repository.
This action allows you to synchronize repositories without granting write permissions to a trusted repository from an untrusted one.

## Features

- **File Copying**: Copy files from a specified path in a source repository to a specified path in the current repository.
- **Customizable Commit Message**: Set a custom commit message for the changes.
- **Pull Request Creation**: Optionally create a pull request with a custom title.
- **Authentication**: Securely authenticate with the source repository using a Personal Access Token (PAT).

## Inputs

| Input Name         | Description                                           | Required | Default                      |
| ------------------ | ----------------------------------------------------- | -------- | ---------------------------- |
| `source_repo`      | The source repository in the format `owner/repo`.     | Yes      | N/A                          |
| `source_path`      | The path in the source repository to copy files from. | Yes      | N/A                          |
| `destination_path` | The path in the current repository to copy files to.  | Yes      | N/A                          |
| `commit_message`   | The commit message for the changes.                   | No       | `Automated file copy commit` |
| `pr_title`         | The title for the pull request.                       | No       | `Automated file copy PR`     |
| `create_pr`        | Whether to create a pull request (`true`/`false`).    | No       | `false`                      |
| `pat`              | Personal Access Token for the source repository.      | Yes      | N/A                          |

## Usage

### Step 1: Configure Authentication

Add the following secrets to your repository:

- `SOURCE_REPO_PAT`: Personal Access Token for the source repository.

> [!IMPORTANT]  
> Ensure the Personal Access Token (PAT) has the necessary permissions to access/read the source repository.

### Step 2: Define Workflow Configuration

Create a workflow file named `copy-files.yml` in `.github/workflows/`:

```yaml
name: Copy Files from Source Repo

on:
  push:
    branches:
      - main

jobs:
  copy-files:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Run file copy action
        uses: ./ # Uses an action in the same repository
        with:
          source_repo: "owner/source-repo"
          source_path: "path/to/copy"
          destination_path: "path/to/destination"
          commit_message: "Custom commit message"
          pr_title: "Custom PR title"
          create_pr: "true"
          pat: ${{ secrets.SOURCE_REPO_PAT }}
```

### Step 3: Push Changes

Push the `.github/workflows/copy-files.yml` file to your repository to trigger the action.

## Example using a PAT

```yaml
name: Copy Files from Source Repo

on:
  schedule:
    - cron: "0 0 * * *" # Runs every day at midnight

jobs:
  copy-files:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run file copy action
        uses:
        with:
          source_repo: "octocat/source-repo"
          source_path: "data/files"
          destination_path: "data/destination"
          commit_message: "Daily automated file copy commit"
          pr_title: "Daily automated file copy PR"
          create_pr: "true"
          source_repo_token: ${{ secrets.SOURCE_REPO_PAT }}
```

## Example using a GitHub app token

```yaml
name: Copy Files from Source Repo

on:
  schedule:
    - cron: "0 0 * * *" # Runs every day at midnight

jobs:
  copy-files:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Generate token
        id: create_token
        uses: tibdex/github-app-token@v2
        with:
          app_id: ${{ secrets.APP_ID }}
          private_key: ${{ secrets.APP_PRIVATE_KEY }}

      - name: Run file copy action
        uses:
        with:
          source_repo: "octocat/source-repo"
          source_path: "data/files"
          destination_path: "data/destination"
          commit_message: "Daily automated file copy commit"
          pr_title: "Daily automated file copy PR"
          create_pr: "true"
          source_repo_token: ${{ steps.create_token.outputs.token }}
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or fixes.

## Libraries Used

This action uses the following libraries:

- `@actions/core`: Core functions for GitHub Actions.
- `@actions/github`: GitHub API wrapper for interacting with GitHub.
- `@actions/exec`: Functions to execute commands.
- `@octokit/rest`: REST API client for GitHub.

---

For any questions or support, please open an issue in this repository.
