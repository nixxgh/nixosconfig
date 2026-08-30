{ self, inputs, ... }: {
  flake.nixosModules.audio = { pkgs, lib, config, ... }: {
    # Disable the old PulseAudio server
    hardware.pulseaudio.enable = false;
    
    # RTKit is highly recommended for PipeWire to ensure smooth audio
    security.rtkit.enable = true;
    
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
