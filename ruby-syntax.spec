%define		ruby_rubylibdir	%(ruby -r rbconfig -e 'print Config::CONFIG["rubylibdir"]')
%define		ruby_ridir	%(ruby -r rbconfig -e 'include Config; print File.join(CONFIG["datadir"], "ri", CONFIG["ruby_version"], "system")')

Summary:	Syntax classes for specifying BNF-like grammar in Ruby
Name:		ruby-syntax
Version:	0.1
Release:	1
License:	GPL
Group:		Development/Libraries
Source0:	syntax.rb
# Source0-md5:	2c0b1110029d6b3e7d64d9a141021bc3
Source1:	setup.rb
URL:	http://raa.ruby-lang.org/project/syntax/
BuildRequires:	ruby
#BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
Syntax classes for specifying BNF-like grammar in Ruby.

%prep
%setup -c -T

%build
mkdir lib
cp %{SOURCE0} lib
cp %{SOURCE1} .
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
%{ruby_ridir}/*
