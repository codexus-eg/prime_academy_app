class NavLink {
  const NavLink({required this.label, required this.to});

  final String label;

  final String to;
}

abstract final class NavLinks {
  static const List<NavLink> links = [
    NavLink(label: 'من نحن', to: '/about'),
    NavLink(label: 'تواصل معنا', to: '/contact'),
  ];
}
