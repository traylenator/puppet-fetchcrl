# frozen_string_literal: true

def prepare_host
  return unless %w[RedHat Rocky AlmaLinux CentOS OracleLinux].include?(fact('os.name'))

  package = if fact('os.name') == 'OracleLinux' && fact('os.release.major').to_i >= 10
              "oracle-epel-release-el#{fact('os.release.major')}"
            else
              'epel-release'
            end

  shell("yum install -y #{package}")
end
