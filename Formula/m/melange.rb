class Melange < Formula
  desc "Build APKs from source code"
  homepage "https://github.com/chainguard-dev/melange"
  url "https://github.com/chainguard-dev/melange/archive/refs/tags/v0.13.7.tar.gz"
  sha256 "af86ad9146226e22807b000618849dadc551f3ed88d92eeb5905b0f48d16a4cd"
  license "Apache-2.0"
  head "https://github.com/chainguard-dev/melange.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "7bee9a88c122463da3dcd6b7414db03c33ca897fd340df7b9b1c908c1df37354"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "7bee9a88c122463da3dcd6b7414db03c33ca897fd340df7b9b1c908c1df37354"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "7bee9a88c122463da3dcd6b7414db03c33ca897fd340df7b9b1c908c1df37354"
    sha256 cellar: :any_skip_relocation, sonoma:        "909caf995b8cc2183dd8e82749161e971ffb742b2f782d114cfb7a984602eac4"
    sha256 cellar: :any_skip_relocation, ventura:       "909caf995b8cc2183dd8e82749161e971ffb742b2f782d114cfb7a984602eac4"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "2184fcede63f99c9e9f5b18f9e2ef89e2ddbeba9d579cfe304236f2e257a8327"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X sigs.k8s.io/release-utils/version.gitVersion=#{version}
      -X sigs.k8s.io/release-utils/version.gitCommit=brew
      -X sigs.k8s.io/release-utils/version.gitTreeState=clean
      -X sigs.k8s.io/release-utils/version.buildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"melange", "completion")
  end

  test do
    (testpath/"test.yml").write <<~EOS
      package:
        name: hello
        version: 2.12
        epoch: 0
        description: "the GNU hello world program"
        copyright:
          - paths:
            - "*"
            attestation: |
              Copyright 1992, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2005,
              2006, 2007, 2008, 2010, 2011, 2013, 2014, 2022 Free Software Foundation,
              Inc.
            license: GPL-3.0-or-later
        dependencies:
          runtime:

      environment:
        contents:
          repositories:
            - https://dl-cdn.alpinelinux.org/alpine/edge/main
          packages:
            - alpine-baselayout-data
            - busybox
            - build-base
            - scanelf
            - ssl_client
            - ca-certificates-bundle

      pipeline:
        - uses: fetch
          with:
            uri: https://ftp.gnu.org/gnu/hello/hello-${{package.version}}.tar.gz
            expected-sha256: cf04af86dc085268c5f4470fbae49b18afbc221b78096aab842d934a76bad0ab
        - uses: autoconf/configure
        - uses: autoconf/make
        - uses: autoconf/make-install
        - uses: strip
    EOS

    assert_equal "hello-2.12-r0", shell_output("#{bin}/melange package-version #{testpath}/test.yml")

    system bin/"melange", "keygen"
    assert_predicate testpath/"melange.rsa", :exist?

    assert_match version.to_s, shell_output(bin/"melange version 2>&1")
  end
end
