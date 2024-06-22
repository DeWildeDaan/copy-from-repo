const core = require("@actions/core");
const github = require("@actions/github");
const exec = require("@actions/exec");
const { Octokit } = require("@octokit/rest");

async function run() {
  try {
    const sourceRepo = core.getInput("source_repo");
    const sourcePath = core.getInput("source_path");

    const destinationPath = core.getInput("destination_path");

    const commitMessage = core.getInput("commit_message");
    const createPr = core.getInput("create_pr") === "true";
    const prTitle = core.getInput("pr_title");

    const source_repo_token = core.getInput("source_repo_token");
    const token = process.env.GITHUB_TOKEN;

    const octokit = new Octokit({ auth: token });

    // Clone the source repository
    await exec.exec(
      `git clone https://x-access-token:${source_repo_token}@github.com/${sourceRepo}.git source-repo`
    );

    // Copy files from source to destination
    await exec.exec(`cp -r source-repo/${sourcePath} ${destinationPath}`);

    // Configure git
    await exec.exec(`git config --global user.name "${github.context.actor}"`);
    await exec.exec(
      `git config --global user.email "${github.context.actor}@users.noreply.github.com"`
    );

    // Add, commit, and push changes
    await exec.exec(`git add ${destinationPath}`);
    await exec.exec(`git commit -m "${commitMessage}"`);
    await exec.exec(`git push`);

    if (createPr) {
      const [owner, repo] = process.env.GITHUB_REPOSITORY.split("/");
      const base = github.context.ref.replace("refs/heads/", "");
      const head = `auto-file-copy-${new Date().getTime()}`;

      // Create a new branch for the PR
      await exec.exec(`git checkout -b ${head}`);
      await exec.exec(`git push --set-upstream origin ${head}`);

      // Create the PR
      await octokit.pulls.create({
        owner,
        repo,
        title: prTitle,
        head,
        base,
      });
    }
  } catch (error) {
    core.setFailed(error.message);
  }
}

run();
