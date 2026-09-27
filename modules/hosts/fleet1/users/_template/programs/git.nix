{ self, inputs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Your Name";
        email = "your.email@example.com";
      };
      init.defaultBranch = "main";
    };
  };
}
