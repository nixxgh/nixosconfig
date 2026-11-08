{ self, inputs, ... }: {
  flake.overlays.hyprlock = final: prev: {
    hyprlock = prev.hyprlock.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/renderer/AsyncResourceManager.cpp \
          --replace-fail '    m_gatherer.enqueue(resource);

    m_resourcesMutex.lock();' '    m_resourcesMutex.lock();' \
          --replace-fail '            (void*)resourceID);
    });
}' '            (void*)resourceID);
    });

    m_gatherer.enqueue(resource);
}'
      '';
    });
  };
}
