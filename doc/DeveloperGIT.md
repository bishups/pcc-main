Git Usage Reference
===================

Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

Learning Git:


* http://try.github.io

Core Operations:

* Clone Repository
* Create Developer Branch
* Commit Changes
* Push Changes to Remote Repository

Cloning Repository
------------------

```
git clone https://github.com/bishups/pcc-main.git
```

The above command will download the source code to *pcc-main* directory.

Creating Developer Branch
-------------------------

http://git-scm.com/book/en/Git-Branching-Basic-Branching-and-Merging

```
git checkout -b developer1
```

The above command will switch the current branch to developer1. The -b switch will ensure that the branch is created if it does not exist.

To switch between different branches:

```
git checkout master
```

```
git checkout developer2
```

```
git checkout developer3
```


