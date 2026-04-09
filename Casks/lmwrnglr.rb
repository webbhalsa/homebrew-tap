cask "lmwrnglr" do
  version "0.1.5"
  sha256 "ddeed018057ec63a4ab847485fbd827c4c85aff9a81172de6f09f12b6f59269f"

  url "https://github.com/webbhalsa/homebrew-tap/releases/download/lmwrnglr-v0.1.5/lmwrnglr-0.1.5-universal-mac.zip"

  name "lmwrnglr"
  desc "Multi-terminal manager for AI coding sessions"
  homepage "https://github.com/webbhalsa/claude-skills/tree/main/applications/lmwrnglr"

  app "lmwrnglr.app"

  zap trash: [
    "~/Library/Application Support/lmwrnglr",
    "~/Library/Preferences/com.lmwrnglr.app.plist",
    "~/Library/Saved Application State/com.lmwrnglr.app.savedState",
  ]
end
