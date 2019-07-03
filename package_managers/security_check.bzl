# Copyright 2017 Google Inc. All rights reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def _impl(ctx):
    _security_check = ctx.executable._security_check
    output_yaml = ctx.outputs.yaml
    args = [
        ctx.attr.image,
        "--output-yaml",
        ctx.outputs.yaml.path,
        "--severity",
        ctx.attr.severity,
    ]
    if ctx.attr.whitelist != None:
        files = ctx.attr.whitelist.files.to_list()
        if len(files) != 1:
            fail(
                "Got {} files in label {} given to {}. Expected exactly 1.".format(
                    len(files),
                    ctx.attr.whitelist.label,
                    ctx.label,
                ),
            )
        args.append("--whitelist-file")
        args.append(files[0].path)
    ctx.actions.run(
        executable = ctx.executable._security_check,
        arguments = args,
        outputs = [ctx.outputs.yaml],
        mnemonic = "ImageSecurityCheck",
        use_default_shell_env = True,
        execution_requirements = {
            # This is needed because security_check.py invokes gcloud which
            # writes/reads gcloud configuration files under $HOME/.config or
            # the directory indicated in the environment variable
            # CLOUDSDK_CONFIG if set.
            "no-sandbox": "True",
        },
    )

# Run the security_check.py script on the given docker image to generate a
# YAML output file with information about the types of vulnerabilities
# discovered in the given image.
security_check = rule(
    implementation = _impl,
    attrs = {
        "image": attr.string(
            mandatory = True,
            doc = "Name of the remote image to run the security check on.",
        ),
        "severity": attr.string(
            doc = "The minimum severity to filter on. " +
                  "Options: LOW, MEDIUM, HIGH, CRITICAL",
            default = "MEDIUM",
            values = ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
        ),
        "whitelist": attr.label(
            doc = "The path to the whitelist json file",
            default = Label("@base_images_docker//package_managers:security_check_whitelist.json"),
            allow_single_file = True,
        ),
        # The security checker python executable.
        "_security_check": attr.label(
            default = Label("@base_images_docker//package_managers:security_check"),
            cfg = "host",
            executable = True,
            allow_files = True,
        ),
    },
    outputs = {
        "yaml": "%{name}.yaml",
    },
)
