;; extends

; https://medium.com/@jogarcia/laravel-blade-on-neovim-ee530ff5d20d

((text) @injection.content
    (#not-has-ancestor? @injection.content "envoy")
    (#set! injection.combined)
    (#set! injection.language php))
