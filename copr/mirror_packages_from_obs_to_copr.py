#!/usr/bin/env python3
import os.path
import sys
from collections import deque
import urllib.request
import re

if len(sys.argv) != 2:
  print("Please specify which Kolab version to run this script for. eg. 3.4, or 3.4-updates")
  sys.exit(-1)
release=sys.argv[1]
rpmbuildpath="/root/rpmbuild"
pkgurl="https://tpokorra.fedorapeople.org/kolab/kolab-"+release
if "updates" in release:
  obsurl="http://obs.kolabsys.com/repositories/Kolab:/" + release[:-8] + ":/Updates/CentOS_7/src/"
else:
  obsurl="http://obs.kolabsys.com/repositories/Kolab:/" + release + "/CentOS_7/src/"
fedorapeopleurl="tpokorra@fedorapeople.org:public_html/kolab"
srcrpmspath="/root/obs/kolab-"+release
Debugging=False

def GetDependanciesAndProvides(name):
    specfile=rpmbuildpath + "/SPECS/" + name + ".spec"
    builddepends=[]
    provides={}
    if not os.path.isfile(specfile):
      print("cannot find " + specfile)
    else:
      for line in open(specfile):
        if line.lower().startswith("buildrequires: "):
          if line.count(",") > 0:
            packagesWithVersions=line[len("BuildRequires: "):].split(",")
          else:
            packagesWithVersions=line[len("BuildRequires: "):].split()
          ignoreNext=False
          for word in packagesWithVersions:
            if not ignoreNext:
              # filter >= 3.0, only use package names
              if word[0] == '>' or word[0] == '<' or word[0] == '=':
                ignoreNext=True
              else:
                builddepends.append(word.strip())
            else:
              ignoreNext=False

      recentpackagename=name
      for line in open(specfile):
        if line.lower().startswith("name:"):
          name = line[len("name:"):].strip()
          recentpackagename=name
          provides[name] = []
        elif line.lower().startswith("%package -n"):
          recentpackagename=line[len("%package -n"):].strip()
          provides[recentpackagename] = []
        elif line.lower().startswith("%package"):
          recentpackagename=name + "-" + line[len("%package"):].strip()
          provides[recentpackagename] = []
        elif line.lower().startswith("requires:"):
          r = line[len("requires:"):].strip().replace("(", "-").replace(")", "")
          provides[recentpackagename].append(r.split()[0])

    return (builddepends, provides)

def CalculatePackageOrder(packages):
    unsorted={}
    builddepends={}
    depends={}
    provides={}
    for package in packages:
      (builddepends[package],provides[package]) = GetDependanciesAndProvides(package)
      for p in provides[package]:
          unsorted[p] = 1
          depends[p] = provides[package][p]
      if not package in unsorted:
          unsorted[package] = 1
      # useful for debugging:
      if Debugging:
          print( package + " builddepends on: ")
          for p in builddepends[package]:
            print("   " + p)
          print( package + " provides: ")
          for p in provides[package]:
            print("   " + p + " which depends on:")
            for d in depends[p]:
              print("      " + d)

    result = deque()
    while len(unsorted) > 0:
      nextPackages = []
      for package in unsorted:
        if package in packages:
          missingRequirement=False
          # check that this package does not require a package that is in unsorted
          for dep in builddepends[package]:
            if dep in unsorted:
              missingRequirement=True
            if dep in depends:
              for dep2 in depends[dep]:
                if dep2 in unsorted:
                  missingRequirement=True
          if not missingRequirement:
            nextPackages.append(package)
            added=True
      if nextPackages.count == 0:
        # problem: circular dependancy
        print ("circular dependancy, remaining packages: ")
        for p in unsorted:
          print(p)
        return None
      result.append(nextPackages)
      for pkg in nextPackages:
        for p in provides[pkg]:
          if p in unsorted:
            del unsorted[p]
      for pkg in nextPackages:
        if pkg in unsorted:
          del unsorted[pkg]

    return result

def getPackages():
  packages=[]
  for file in os.listdir(rpmbuildpath+"/SPECS"):
    if file.endswith(".spec"):
        packages.append(file[:-5])
  return packages

def getSrcRpmFiles(packages):
  result={}

  # parse name from spec file
  srcrpmnames={}
  for pkg in packages:
    srcrpmnames[pkg] = pkg
    for line in open(rpmbuildpath+"/SPECS/" + pkg + ".spec"):
      if line.startswith("Name: "):
        srcrpmnames[pkg] = line[6:].strip()

  for file in os.listdir(srcrpmspath):
    if file.endswith(".src.rpm"):
      bestfit=None
      bestfitCount=0
      for pkg in packages:
        pkgsrcname = srcrpmnames[pkg]
        if file.startswith(pkgsrcname):
          if len(pkgsrcname) > bestfitCount:
            bestfitCount=len(pkgsrcname)
            bestfit=pkg
      if bestfit is not None:
        result[bestfit] = file
  return result

def downloadSrcRpms():
  if os.path.isdir(srcrpmspath):
    print("not downloading the src.rpms again. please delete the path " + srcrpmspath + " if you want a fresh download")
    return
  response = urllib.request.urlopen(obsurl)
  html = response.read().decode('utf-8')
  for line in html.split('\n'):
    if "src.rpm" in line:
      m = re.search('<a [^>]+>', line)
      m2 = re.search('"[^\"]+"', m.group(0))
      srcrpm=m2.group(0).strip('"')
      os.system("wget " + obsurl + "/" + srcrpm + " -O " + srcrpmspath + "/" + srcrpm)

def uploadSrcRpms():
  os.system("echo 'put *.src.rpm' | sftp " + fedorapeopleurl + "/kolab-" + release)

def installSrcRpms():
  # need a clean rpmbuild directory
  if os.path.isdir(rpmbuildpath):
    if os.path.isdir(rpmbuildpath + ".bak"):
      print("Error: cannot rename " + rpmbuildpath + " because " + rpmbuildpath + ".bak already exist")
      sys.exit(-1)
    os.rename(rpmbuildpath, rpmbuildpath + ".bak")
  for file in os.listdir(srcrpmspath):
    if file.endswith(".src.rpm"):
      os.system("rpm -i " + srcrpmspath + "/" + file)

#downloadSrcRpms()
#uploadSrcRpms()
installSrcRpms()
packages=getPackages()
srcrpmfiles=getSrcRpmFiles(packages)
orderedpackages=CalculatePackageOrder(packages)
for pkgs in orderedpackages:
  print()
  print("build together: ")
  for pkg in pkgs:
    if pkg in srcrpmfiles:
      print(pkgurl + "/" + srcrpmfiles[pkg])
    else:
      print("   " + pkg);
