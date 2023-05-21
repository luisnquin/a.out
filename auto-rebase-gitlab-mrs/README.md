
# Auto-rebase GitLab MRs

## About the environment variables

- `GITLAB_PERSONAL_TOKEN` is a token generated in your GitLab account, it must have `API` scope.
- `GITLAB_HOST` is normally just `https://gitlab.com`, it will depend on where your project is hosted.
- `GITLAB_PROJECT_ID` is extracted from the main page of your target project (e.g. 10).
