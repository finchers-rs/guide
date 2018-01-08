# Imported from rust-lang-nursery/api-guidelines/deploy.sh

set -o errexit -o nounset

get_branch() {
    if [[ "${TRAVIS_PULL_REQUEST:-}" == false ]]; then
        echo "${TRAVIS_BRANCH}"
    else
        echo "${TRAVIS_PULL_REQUEST_BRANCH}"
    fi
}

if [[ -z "${TRAVIS_BRANCH:-}" ]]; then
    echo "This script may only be run from Travis CI."
    exit 1
fi

BRANCH="$(get_branch)"
if [[ "${BRANCH}" != "master" ]]; then
    echo "The deployment should be from 'master', not '${BRANCH}'."
    exit 1
fi

REV="$(git rev-parse --short HEAD)"
UPSTREAM_URL="https://${GH_TOKEN}@github.com/finchers-rs/guide.git"
USERNAME="Yusuke Sasaki"
EMAIL="yusuke.sasaki.nuem@gmail.com"

echo "Committing book directory to gh-pages branch"
cd book
git init
git remote add upstream "${UPSTREAM_URL}"
git config user.name "${USERNAME}"
git config user.email "${EMAIL}"
git add -A .
git commit -qm "Build documentation at ${TRAVIS_REPO_SLUG}@${REV}"

echo "Pushing gh-pages to GitHub"
git push -q upstream HEAD:refs/heads/gh-pages --force
