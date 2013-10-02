exports.config =
    # See docs at http://brunch.readthedocs.org/en/latest/config.html.
    coffeelint:
        pattern: /^app\/.*\.coffee$/
        options:
            indentation:
                value: 4
                level: "warn"

    files:
        javascripts:
            joinTo:
                'javascripts/app.js': /^app/
                'javascripts/vendor.js': /^vendor/
                'test/javascripts/test.js': /^test(\/|\\)(?!vendor)/
                'test/javascripts/test-vendor.js': /^test(\/|\\)(?=vendor)/
            order:
                # Files in `vendor` directories are compiled before other files
                # even if they aren't specified in order.
                before: [
                    'vendor/scripts/jquery-1.8.2.js'
                    'vendor/scripts/lodash-v0.8.2.js'
                    'vendor/scripts/backbone-0.9.2.js'
                    'vendor/scripts/three.js'
                    'vendor/scripts/FXAAShader.js'
                    'vendor/scripts/VignetteShader.js'
                    'vendor/scripts/VerticalTiltShiftShader.js'
                    'vendor/scripts/HorizontalTiltShiftShader.js'
                    'vendor/scripts/CopyShader.js'
                    'vendor/scripts/EffectComposer.js'
                    'vendor/scripts/RenderPass.js'
                    'vendor/scripts/MaskPass.js'
                    'vendor/scripts/ShaderPass.js'
                ]
                after: [
                ]
        stylesheets:
            joinTo: 'stylesheets/app.css'
            order:
                before: ['vendor/styles/normalize.css']
                after: ['vendor/styles/helpers.css']

        templates:
            joinTo: 'javascripts/app.js'
