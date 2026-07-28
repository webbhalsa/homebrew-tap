# typed: false
# frozen_string_literal: true

# Downloads release assets from private/internal GitHub repositories.
#
# Their release tarballs can't be fetched over unauthenticated HTTPS, and
# Homebrew's built-in GitHubPrivateRepositoryReleaseDownloadStrategy was removed,
# so we vendor our own here. It reads a token from HOMEBREW_GITHUB_API_TOKEN,
# resolves the release asset via the GitHub API, and downloads it authenticated.
#
# Users must export a token with read access to the source repository, e.g.:
#     export HOMEBREW_GITHUB_API_TOKEN="$(gh auth token)"
#
# Formulas opt in via `using: GitHubPrivateRepositoryReleaseDownloadStrategy`.
require "download_strategy"

class GitHubPrivateRepositoryReleaseDownloadStrategy < CurlDownloadStrategy
  require "utils/github"

  def initialize(url, name, version, **meta)
    super
    parse_url_pattern
    set_github_token
  end

  def parse_url_pattern
    # Anchored; tag segment allows `/` (valid in git tags), filename is the last segment.
    url_pattern = %r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/(.+)/([^/]+)\z}
    unless @url =~ url_pattern
      raise CurlDownloadStrategyError, "Invalid URL pattern for GitHub release: #{@url}"
    end

    _, @owner, @repo, @tag, @filename = *@url.match(url_pattern)
  end

  def set_github_token
    @github_token = ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", nil)
    return unless @github_token.nil? || @github_token.empty?

    raise CurlDownloadStrategyError, <<~EOS
      HOMEBREW_GITHUB_API_TOKEN is required to download release assets from a
      private GitHub repository. Set it to a token with read access, e.g.:

          export HOMEBREW_GITHUB_API_TOKEN="$(gh auth token)"
    EOS
  end

  def download_url
    "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id}"
  end

  private

  def _fetch(url: nil, resolved_url: nil, timeout: nil, **)
    args = [
      download_url,
      "--header", "Accept: application/octet-stream",
      "--header", "Authorization: token #{@github_token}",
    ]
    # Honor Homebrew's download timeout so a stalled transfer aborts as expected.
    args += ["--max-time", timeout.to_s] if timeout && timeout.to_f.positive?
    curl_download(*args, to: temporary_path)
  end

  def asset_id
    @asset_id ||= resolve_asset_id
  end

  def resolve_asset_id
    asset = fetch_release_metadata["assets"].find { |a| a["name"] == @filename }
    raise CurlDownloadStrategyError, "Release asset not found: #{@filename}" if asset.nil?

    asset["id"]
  end

  def fetch_release_metadata
    release_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"
    GitHub::API.open_rest(release_url)
  end
end
