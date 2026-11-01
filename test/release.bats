#!/usr/bin/env bats

load test_helper

# Create a project with the release script, a bare origin, and a GitHub CLI
# stub that logs its arguments. RELEASE_VIEW selects what `gh release view`
# reports: missing, or draft or published followed by the asset names.
setup_release_project() {
  PROJECT="${BATS_TEST_TMPDIR}/project"
  ORIGIN="${BATS_TEST_TMPDIR}/origin.git"
  GH_LOG="${BATS_TEST_TMPDIR}/gh.log"
  export GH_LOG RELEASE_VIEW='missing'
  export GIT_CONFIG_GLOBAL="${BATS_TEST_TMPDIR}/gitconfig" GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME='Test' GIT_AUTHOR_EMAIL='test@example.com'
  export GIT_COMMITTER_NAME='Test' GIT_COMMITTER_EMAIL='test@example.com'
  : >"${GIT_CONFIG_GLOBAL}"
  : >"${GH_LOG}"

  mkdir -p "${PROJECT}/scripts" "${PROJECT}/src" "${BATS_TEST_TMPDIR}/bin"
  cp "${PROJECT_ROOT}/scripts/release" "${PROJECT}/scripts/release"
  printf '%s\n' '#!/usr/bin/env bash' "readonly BASHSTOCK_VERSION='1.0.0'" >"${PROJECT}/src/settings.sh"
  printf 'dist/\n' >"${PROJECT}/.gitignore"
  cat >"${BATS_TEST_TMPDIR}/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${GH_LOG}"
if [[ "$1 $2" == 'release view' ]]; then
  case "${RELEASE_VIEW}" in
    missing)
      printf 'release not found\n' >&2
      exit 1
      ;;
    *) printf '%s\n' "${RELEASE_VIEW}" ;;
  esac
fi
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/gh"
  PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"

  git init --quiet --bare "${ORIGIN}"
  git -C "${PROJECT}" init --quiet --initial-branch=main
  git -C "${PROJECT}" add .
  git -C "${PROJECT}" commit --quiet --message 'initial'
  git -C "${PROJECT}" remote add origin "${ORIGIN}"
  git -C "${PROJECT}" push --quiet --set-upstream origin main
}

# Merge a release branch into main on origin as a merged pull request would.
merge_release() {
  local version="$1"
  git -C "${PROJECT}" switch --quiet main
  git -C "${PROJECT}" merge --quiet --no-ff --message "Merge release/${version}" "release/${version}"
  git -C "${PROJECT}" push --quiet origin main
  mkdir -p "${PROJECT}/dist"
  printf 'distribution\n' >"${PROJECT}/dist/bashstock.sh"
}

@test "bump opens a pull request from a release branch with the new version" {
  setup_release_project

  run bash "${PROJECT}/scripts/release" bump 1.2.0
  [ "${status}" -eq 0 ]
  [ "$(git -C "${PROJECT}" symbolic-ref --short HEAD)" = 'release/1.2.0' ]
  [ "$(git -C "${PROJECT}" show release/1.2.0:src/settings.sh | tail -n 1)" = "readonly BASHSTOCK_VERSION='1.2.0'" ]
  [ "$(git -C "${PROJECT}" log -1 --format=%s release/1.2.0)" = 'chore(release): 1.2.0' ]
  [ -n "$(git -C "${PROJECT}" ls-remote --heads origin release/1.2.0)" ]
  [[ "$(<"${GH_LOG}")" == 'pr create --base main --head release/1.2.0 --title chore(release): 1.2.0 '* ]]
}

@test "bump releases the version already in the source with an empty commit" {
  setup_release_project

  run bash "${PROJECT}/scripts/release" bump 1.0.0
  [ "${status}" -eq 0 ]
  [ "$(git -C "${PROJECT}" rev-list --count main..release/1.0.0)" = 1 ]
  [ -z "$(git -C "${PROJECT}" diff main release/1.0.0)" ]
}

@test "bump with --dry-run checks the version and changes nothing" {
  setup_release_project

  run bash "${PROJECT}/scripts/release" bump 1.2.0 --dry-run
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'would open the release pull request from release/1.2.0'* ]]
  [ "$(git -C "${PROJECT}" symbolic-ref --short HEAD)" = 'main' ]
  [ -z "$(git -C "${PROJECT}" ls-remote --heads origin release/1.2.0)" ]
  [ ! -s "${GH_LOG}" ]
}

@test "bump rejects an invalid version, a dirty tree, and a branch other than main" {
  setup_release_project

  run bash "${PROJECT}/scripts/release" bump 1.2
  [ "${status}" -eq 64 ]
  run bash "${PROJECT}/scripts/release" bump 1.2.0-1
  [ "${status}" -eq 64 ]

  printf '# changed\n' >>"${PROJECT}/src/settings.sh"
  run bash "${PROJECT}/scripts/release" bump 1.2.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'uncommitted changes'* ]]
  git -C "${PROJECT}" checkout --quiet -- src/settings.sh

  printf '# staged\n' >>"${PROJECT}/src/settings.sh"
  git -C "${PROJECT}" add src/settings.sh
  git -C "${PROJECT}" show HEAD:src/settings.sh >"${PROJECT}/src/settings.sh"
  run bash "${PROJECT}/scripts/release" bump 1.2.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'uncommitted changes'* ]]
  git -C "${PROJECT}" reset --quiet --hard

  git -C "${PROJECT}" switch --quiet --create feature/other
  run bash "${PROJECT}/scripts/release" bump 1.2.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'switch to main'* ]]
}

@test "bump rejects a version that is not higher than every release tag" {
  setup_release_project
  git -C "${PROJECT}" tag v1.2.0
  git -C "${PROJECT}" tag v2.0.0-preview2
  git -C "${PROJECT}" push --quiet origin --tags

  run bash "${PROJECT}/scripts/release" bump 1.2.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'already tagged'* ]]
  run bash "${PROJECT}/scripts/release" bump 2.0.0-preview10
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'not higher than the released v2.0.0-preview2'* ]]
  run bash "${PROJECT}/scripts/release" bump 2.0.0-preview3 --dry-run
  [ "${status}" -eq 0 ]
  run bash "${PROJECT}/scripts/release" bump 2.0.0 --dry-run
  [ "${status}" -eq 0 ]
}

@test "publish tags the merge commit and creates the GitHub Release" {
  setup_release_project
  bash "${PROJECT}/scripts/release" bump 1.2.0
  merge_release 1.2.0
  local commit=''
  commit="$(git -C "${PROJECT}" rev-parse HEAD)"

  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/1.2.0
  [ "${status}" -eq 0 ]
  [ "$(git -C "${ORIGIN}" rev-parse 'v1.2.0^{commit}')" = "${commit}" ]
  [ "$(tail -n 1 "${GH_LOG}")" = 'release create v1.2.0 dist/bashstock.sh --title v1.2.0 --generate-notes --verify-tag' ]
}

@test "publish marks a prerelease and completes an interrupted release" {
  setup_release_project
  bash "${PROJECT}/scripts/release" bump 2.0.0-preview1
  merge_release 2.0.0-preview1
  local commit=''
  commit="$(git -C "${PROJECT}" rev-parse HEAD)"

  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/2.0.0-preview1
  [ "${status}" -eq 0 ]
  [[ "$(tail -n 1 "${GH_LOG}")" == *' --prerelease' ]]

  RELEASE_VIEW='draft '
  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/2.0.0-preview1
  [ "${status}" -eq 0 ]
  [ "$(tail -n 2 "${GH_LOG}")" = $'release upload v2.0.0-preview1 dist/bashstock.sh --clobber\nrelease edit v2.0.0-preview1 --draft=false --prerelease=true --verify-tag' ]

  RELEASE_VIEW='published '
  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/2.0.0-preview1
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'already tagged'* ]]
  [ "$(tail -n 1 "${GH_LOG}")" = 'release upload v2.0.0-preview1 dist/bashstock.sh' ]

  RELEASE_VIEW='published bashstock.sh'
  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/2.0.0-preview1
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'already published'* ]]
}

@test "publish rejects a version mismatch, an unmerged commit, and a moved tag" {
  setup_release_project
  bash "${PROJECT}/scripts/release" bump 1.2.0
  local unmerged=''
  unmerged="$(git -C "${PROJECT}" rev-parse HEAD)"
  merge_release 1.2.0
  local commit=''
  commit="$(git -C "${PROJECT}" rev-parse HEAD)"

  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/1.3.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'declares 1.2.0, not 1.3.0'* ]]

  git -C "${PROJECT}" tag v1.2.0 HEAD~1
  git -C "${PROJECT}" push --quiet origin v1.2.0
  run bash "${PROJECT}/scripts/release" publish "${commit}" --branch release/1.2.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *"points to"* ]]

  git -C "${PROJECT}" switch --quiet --detach "${unmerged}"
  git -C "${PROJECT}" commit --quiet --allow-empty --message 'unmerged'
  run bash "${PROJECT}/scripts/release" publish HEAD --branch release/1.2.0
  [ "${status}" -eq 65 ]
  [[ "${output}" == *'is not on origin/main'* ]]
}
