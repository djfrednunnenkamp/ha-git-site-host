# HA Git Site Host

Host a static website directly from a Git repository inside Home Assistant.

This add-on automatically clones a Git repository, extracts a static site (for example a Vite/React build), and serves it using Nginx inside Home Assistant.

It periodically checks the repository for updates and republishes the site when new commits are detected.

Perfect for hosting:

* personal dashboards
* React / Vite static sites
* documentation
* landing pages
* simple web apps

---

# Features

* Automatically clones a Git repository
* Periodically checks for new commits
* Publishes static files automatically
* Serves the site with Nginx
* Lightweight and fast
* No external server required

---

# How it works

1. The add-on clones your Git repository.
2. It looks for a directory containing the built site (for example `dist/`).
3. Files are copied into the web server directory.
4. Nginx serves the site on port **8099**.
5. The add-on periodically checks the repository for updates.

If a new commit is detected:

* The repository is pulled
* The site files are updated
* Nginx reloads automatically

---

# Installation

1. Open **Home Assistant**

2. Go to:

Settings → Add-ons → Add-on Store

3. Add this repository:

https://github.com/YOUR_USERNAME/ha-git-site-host

4. Install **HA Git Site Host**

---

# Configuration

Example configuration:

```yaml
repo_url: https://github.com/username/my-site
branch: main
site_subdir: dist
poll_interval: 60
clean_on_update: true
github_token: ""
```

---

# Configuration Options

## repo_url

URL of the Git repository containing the site.

Example:

```
https://github.com/username/my-site
```

Required.

---

## branch

Git branch to use.

Example:

```
main
```

Default:

```
main
```

---

## site_subdir

Directory inside the repository containing the built static site.

Examples:

| Framework    | Folder |
| ------------ | ------ |
| React / Vite | dist   |
| Vue          | dist   |
| Next export  | out    |
| Static HTML  | .      |

Example:

```
site_subdir: dist
```

---

## poll_interval

Time (in seconds) between repository update checks.

Example:

```
poll_interval: 60
```

Meaning the repository will be checked every **60 seconds**.

---

## clean_on_update

If enabled, the site directory is cleared before copying new files.

Recommended value:

```
clean_on_update: true
```

---

## github_token

Optional GitHub token for private repositories.

Example:

```
github_token: ghp_xxxxxxxxxxxxxxxxx
```

Leave empty for public repositories.

---

# Accessing the Site

Once the add-on is running, the site will be available at:

```
http://HOME_ASSISTANT_IP:8099
```

Example:

```
http://192.168.1.10:8099
```

---

# Example Workflow

Example with a React + Vite project.

## 1. Build the project

```
npm run build
```

This creates:

```
dist/
```

## 2. Push to GitHub

```
git add .
git commit -m "update site"
git push
```

## 3. Wait for the add-on

After the next poll interval:

* The repository is updated
* The new site version goes live automatically

---

# Directory Structure

Example repository:

```
my-site
│
├─ src
├─ public
├─ package.json
└─ dist
   ├─ index.html
   ├─ assets
   └─ ...
```

Set:

```
site_subdir: dist
```

---

# Logs

To see logs:

Add-on → Logs

Example output:

```
[INFO] Checking repo updates...
[INFO] New revision: a8d7c3f
[INFO] Site updated + nginx reloaded.
```

---

# Troubleshooting

## Site shows blank page

Make sure:

* `index.html` exists in `site_subdir`
* the site was built before pushing to Git

Example:

```
dist/index.html
```

---

## Repository not updating

Check:

* branch name
* poll_interval value
* Git repository accessibility

---

# Security

If using private repositories:

Use a **GitHub Personal Access Token** in `github_token`.

Example:

```
github_token: ghp_xxxxxxxxx
```

---

# License

MIT
