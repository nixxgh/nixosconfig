{ self, inputs, ... }: {
  flake.nixosModules.audio = { pkgs, lib, config, ... }: {
    # Disable the old PulseAudio server
    services.pulseaudio.enable = false;
    
    # RTKit is highly recommended for PipeWire to ensure smooth audio
    security.rtkit.enable = true;
    
    services.pipewire = {
      enable = true;
      
      # Enable ALSA support for older apps
      alsa.enable = true;
      alsa.support32Bit = true;
      
      # Enable the PulseAudio compatibility layer 
      pulse.enable = true;
      
      # Enable JACK compatibility layer for pro audio apps
      jack.enable = true;

      # ADD THIS: The session manager that routes Bluetooth audio!
      wireplumber.enable = true;
    };
  };
}
