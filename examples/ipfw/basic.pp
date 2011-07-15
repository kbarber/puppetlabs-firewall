firewall { "100 allow foo":
  source => "10.0.1.2",
  destination => "1.1.1.1",
  proto => "tcp",
  dport => 22,
  jump => "ACCEPT",
}
