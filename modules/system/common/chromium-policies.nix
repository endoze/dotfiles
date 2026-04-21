{
  # Homepage
  HomepageLocation = "https://start.duckduckgo.com";
  HomepageIsNewTabPage = false;
  NewTabPageLocation = "https://start.duckduckgo.com";

  # Restore tabs from last session on launch
  RestoreOnStartup = 1;

  # Default search engine
  DefaultSearchProviderEnabled = true;
  DefaultSearchProviderName = "DuckDuckGo";
  DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
  DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

  # Disable password manager
  PasswordManagerEnabled = false;
  AutofillAddressEnabled = false;
  AutofillCreditCardEnabled = false;

  # Allow chromium-web-store extension to be installed
  ExtensionInstallAllowlist = [
    "ocaahdebbfolfmndjeplogmgcagdmblk"
  ];
}
