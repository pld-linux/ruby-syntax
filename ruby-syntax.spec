Summary:	Syntax classes for specifying BNF-like grammar in Ruby
Summary(pl.UTF-8):	Klasy składni do opisu gramatyk typu BNF w języku Ruby
Name:		ruby-syntax
Version:	0.1
Release:	2
License:	GPL
Group:		Development/Libraries
Source0:	syntax.rb
URL:		http://raa.ruby-lang.org/project/syntax/
BuildRequires:	rpm-rubyprov
BuildRequires:	rpmbuild(macros) >= 1.656
BuildRequires:	setup.rb
BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
Syntax classes for specifying BNF-like grammar in Ruby.

%description -l pl.UTF-8
Klasy składni do opisu gramatyk typu BNF w języku Ruby.

%prep
%setup -qcT
install -d lib
cp -p %{SOURCE0} lib
cp -p %{_datadir}/setup.rb .

%build
ruby setup.rb config \
	--site-ruby=%{ruby_vendorlibdir} \
	--so-dir=%{ruby_vendorarchdir}
ruby setup.rb setup

rdoc --inline-source --op rdoc lib
rdoc --ri --op ri lib
rm -r ri/{Array,RandomAccessStream,Range,String}
rm ri/cache.ri
rm ri/created.rid

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{ruby_rubylibdir},%{ruby_ridir}}
ruby setup.rb install \
	--prefix=$RPM_BUILD_ROOT

cp -a ri/* $RPM_BUILD_ROOT%{ruby_ridir}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%{ruby_vendorlibdir}/syntax.rb
%{ruby_ridir}/Syntax
