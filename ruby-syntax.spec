#
# Conditional build:
%bcond_without	tests		# build without tests

%define pkgname syntax
Summary:	Syntax classes for specifying BNF-like grammar in Ruby
Summary(pl.UTF-8):	Klasy składni do opisu gramatyk typu BNF w języku Ruby
Name:		ruby-%{pkgname}
Version:	1.0.0
Release:	1
License:	Public Domain
Group:		Development/Languages
Source0:	http://gems.rubyforge.org/gems/%{pkgname}-%{version}.gem
# Source0-md5:	d9d2eabc03bc937adfa00e35f228f9a8
URL:		http://syntax.rubyforge.org/
BuildRequires:	rpm-rubyprov
BuildRequires:	rpmbuild(macros) >= 1.656
%if %{with tests}
BuildRequires:	ruby-minitest
%endif
BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
Syntax classes for specifying BNF-like grammar in Ruby.

%description -l pl.UTF-8
Klasy składni do opisu gramatyk typu BNF w języku Ruby.

%prep
%setup -q -n %{pkgname}-%{version}

%build
%if %{with tests}
ruby -Itest test/ALL-TESTS.rb
%endif

rdoc --inline-source --op rdoc lib
rdoc --ri --op ri lib
rm ri/cache.ri
rm ri/created.rid

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{ruby_vendorlibdir},%{ruby_ridir}}
cp -a lib/* $RPM_BUILD_ROOT%{ruby_vendorlibdir}
cp -a ri/* $RPM_BUILD_ROOT%{ruby_ridir}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%{ruby_vendorlibdir}/syntax.rb
%{ruby_vendorlibdir}/syntax

%{ruby_ridir}/Syntax
