Summary:	Syntax classes for specifying BNF-like grammar in Ruby
Summary(pl):	Klasy sk�adni do opisu gramatyk typu BNF w j�zyku Ruby
Name:		ruby-syntax
Version:	0.1
Release:	2
License:	GPL
Group:		Development/Libraries
Source0:	syntax.rb
Source1:	setup.rb
URL:		http://raa.ruby-lang.org/project/syntax/
BuildRequires:	rpmbuild(macros) >= 1.263
BuildRequires:	ruby-modules
#BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
Syntax classes for specifying BNF-like grammar in Ruby.

%description -l pl
Klasy sk�adni do opisu gramatyk typu BNF w j�zyku Ruby.

%prep
%setup -q -c -T
mkdir lib
cp %{SOURCE0} lib
cp %{SOURCE1} .

%build
ruby setup.rb config \
	--site-ruby=%{ruby_rubylibdir} \
	--so-dir=%{ruby_archdir}

ruby setup.rb setup
rdoc --inline-source --op rdoc lib
rdoc --ri --op ri lib

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{ruby_rubylibdir},%{ruby_ridir}}

ruby setup.rb install \
	--prefix=$RPM_BUILD_ROOT

cp -a ri/ri/* $RPM_BUILD_ROOT%{ruby_ridir}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%{ruby_rubylibdir}/*
%{ruby_ridir}/Syntax*