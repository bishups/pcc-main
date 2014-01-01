Git Usage Reference
===================

Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

Learning Git:

* http://git-scm.com/book/en/Getting-Started
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

Commiting and Pushing Changes
-----------------

```
git status
```

The above command will show the changes in the local repository that has not been commited.

```
git add file1 file2 ...
```

The above command will add (stage) new/modified files for commiting to the local repository.

```
git commit
```

The above command will record the changes in the local repository.

```
git push origin
```

The above command push the changes to the remote repository.


