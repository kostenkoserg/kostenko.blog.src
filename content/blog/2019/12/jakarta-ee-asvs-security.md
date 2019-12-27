title=Why Jakarta EE beats other java solutions from security point of view
date=2019-12-27
type=post
tags=Jakarta EE, Security
status=published
~~~~~~
No one care about security until security incident. In case enterprise development last one can costs too much, so any preventive steps can help.  Significant part part of the OWASP Application Security Verification Standard (**ASVS**) reads:

>**10.2.1** Verify that the application source code and third party libraries do not contain unauthorized phone home or data collection capabilities. Where such functionality exists, obtain the user's permission for it to operate before collecting any data.
**10.2.3** Verify that the application source code and third party libraries do not contain back doors, such as hard-coded or additional undocumented accounts or keys, code obfuscation, undocumented binary blobs, rootkits, or anti-debugging, insecure debugging features, or otherwise out of date, insecure, or hidden functionality that could be used maliciously if discovered.
**10.2.4** Verify that the application source code and third party libraries does not contain time bombs by searching for date and time related functions.
**10.2.5** Verify that the application source code and third party libraries does not contain malicious code, such as salami attacks, logic bypasses, or logic bombs.
**10.2.6** Verify that the application source code and third party libraries do not contain Easter eggs or any other potentially unwanted functionality.
**10.3.2** Verify that the application employs integrity protections, such as code signing or sub-resource integrity. The application must not load or execute code from untrusted sources, such as loading includes, modules, plugins, code, or libraries from untrusted sources or the Internet.
**14.2.4** Verify that third party components come from pre-defined, trusted and continually maintained repositories.

In other words that meaning you should: **"Verify all code including third-party binaries, libraries, frameworks are reviewed for hardcoded credentials (backdoors)."**

In case development according to Jakarta EE specification you shouldn't be able to use poor controlled  third party libraries, as all you need already came with Application Server. In turn, last one is responsible for in time security  updates, ussage of verified libraries and many more...
