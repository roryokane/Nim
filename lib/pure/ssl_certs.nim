#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Scan for SSL/TLS CA certificates on disk
## The default locations can be overridden using the SSL_CERT_FILE and
## SSL_CERT_DIR environment variables.

import os, strutils
from ospaths import existsEnv, getEnv
import strutils

# SECURITY: this unnecessarily scans through dirs/files regardless of the
# actual host OS/distribution. Hopefully all the paths are writeble only by
# root.

# FWIW look for files before scanning entire dirs.

const certificate_paths = [
    # Debian, Ubuntu, Arch: maintained by update-ca-certificates, SUSE, Gentoo
    # NetBSD (security/mozilla-rootcerts)
    # SLES10/SLES11, https://golang.org/issue/12139
    "/etc/ssl/certs/ca-certificates.crt",
    # OpenSUSE
    "/etc/ssl/ca-bundle.pem",
    # Red Hat 5+, Fedora, Centos
    "/etc/pki/tls/certs/ca-bundle.crt",
    # Red Hat 4
    "/usr/share/ssl/certs/ca-bundle.crt",
    # FreeBSD (security/ca-root-nss package)
    "/usr/local/share/certs/ca-root-nss.crt",
    # CentOS/RHEL 7
    "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
    # OpenBSD, FreeBSD (optional symlink)
    "/etc/ssl/cert.pem",
    # Mac OS X
    "/System/Library/OpenSSL/certs/cert.pem",
    # Fedora/RHEL
    "/etc/pki/tls/certs",
    # Android
    "/system/etc/security/cacerts",
    # FreeBSD
    "/usr/local/share/certs",
    # NetBSD
    "/etc/openssl/certs",
]

iterator scanSSLCertificates*(useEnvVars = false): string =
  ## Scan for SSL/TLS CA certificates on disk.
  ##
  ## if `useEnvVars` is true, the SSL_CERT_FILE and SSL_CERT_DIR
  ## environment variables can be used to override the certificate
  ## directories to scan or specify a CA certificate file.
  if existsEnv("SSL_CERT_FILE"):
    yield getEnv("SSL_CERT_FILE")

  elif existsEnv("SSL_CERT_DIR"):
    let p = getEnv("SSL_CERT_DIR")
    for fn in joinPath(p, "*").walkFiles():
      yield fn

  else:
    for p in certificate_paths:
      if p.endsWith(".pem") or p.endsWith(".crt"):
        if existsFile(p):
          yield p
      elif existsDir(p):
        for fn in joinPath(p, "*").walkFiles():
          yield fn

# Certificates management on windows
# when defined(windows) or defined(nimdoc):
#
#   import openssl
#
#   type
#     PCCertContext {.final, pure.} = pointer
#     X509 {.final, pure.} = pointer
#     CertStore {.final, pure.} = pointer
#
#   # OpenSSL cert store
#
#   {.push stdcall, dynlib: "kernel32", importc.}
#
#   proc CertOpenSystemStore*(hprov: pointer=nil, szSubsystemProtocol: cstring): CertStore
#
#   proc CertEnumCertificatesInStore*(hCertStore: CertStore, pPrevCertContext: PCCertContext): pointer
#
#   proc CertFreeCertificateContext*(pContext: PCCertContext): bool
#
#   proc CertCloseStore*(hCertStore:CertStore, flags:cint): bool
#
#   {.pop.}
