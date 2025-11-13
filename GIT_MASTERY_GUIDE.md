# Step-by-Step Git Mastery Guide

## Phase 1: Absolute Basics (1-2 days)

### 1. Understanding Git Fundamentals
**What to read first:**
- [Pro Git Book - Chapter 1: Getting Started](https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control)
- [Atlassian Git Tutorial - Basic Concepts](https://www.atlassian.com/git/tutorials/what-is-version-control)

**Key concepts to master:**
- What is version control?
- Distributed vs centralized VCS
- Git's three states: modified, staged, committed
- Local repository structure (working directory, staging area, .git directory)

### 2. Installation and Initial Setup
**Practice exercises:**
```bash
# Install Git (choose your OS)
# Configure your identity
git config --global user.name "Your Name"
git config --global user.email "email@example.com"

# Verify installation
git --version
git config --list
```

## Phase 2: Core Git Workflow (3-5 days)

### 3. Basic Commands
**Reading:** [Pro Git - Chapter 2: Git Basics](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository)

**Essential commands to practice:**
```bash
# Repository operations
git init                    # Create new repo
git clone <url>            # Clone existing repo

# Basic workflow
git status                  # Check status
git add <file>             # Stage changes
git commit -m "message"    # Commit changes
git log                    # View history

# File operations
git rm <file>              # Remove file
git mv <old> <new>         # Rename file
```

### 4. Understanding the Staging Area
**Practice exercise:**
```bash
# Create a project and practice staging
echo "Hello" > file1.txt
echo "World" > file2.txt
git add file1.txt          # Stage only file1
git commit -m "Add file1"
git add .                  # Stage all changes
git commit -m "Add file2"
```

## Phase 3: Branching and Merging (1 week)

### 5. Branch Management
**Reading:** [Pro Git - Chapter 3: Git Branching](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)

**Key concepts:**
- What is a branch?
- HEAD pointer
- Branch creation and switching

**Practice commands:**
```bash
# Branch operations
git branch                 # List branches
git branch <name>          # Create branch
git checkout <name>        # Switch branch
git checkout -b <name>     # Create and switch
git branch -d <name>       # Delete branch
git branch -D <name>       # Force delete
```

### 6. Merging and Conflicts
**Reading:** [Atlassian Git Merging Tutorial](https://www.atlassian.com/git/tutorials/using-branches/git-merge)

**Practice workflow:**
```bash
# Create divergent branches and merge
git checkout -b feature-branch
# Make changes
git checkout main
git merge feature-branch   # Merge feature into main

# Handle conflicts (when they occur)
git status                 # See conflicts
# Edit conflicted files
git add <resolved-files>
git commit                 # Complete merge
```

## Phase 4: Remote Repositories (3-4 days)

### 7. Working with Remotes
**Reading:** [Pro Git - Chapter 2.5: Working with Remotes](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes)

**Essential commands:**
```bash
# Remote operations
git remote -v              # List remotes
git remote add <name> <url> # Add remote
git fetch <remote>         # Fetch changes
git pull <remote> <branch>  # Fetch and merge
git push <remote> <branch>  # Push changes

# GitHub/GitLab specific
git push -u origin main    # Set upstream
git push origin --delete <branch> # Delete remote branch
```

### 8. Collaboration Workflow
**Reading:** [GitHub Flow Guide](https://guides.github.com/introduction/flow/)

**Common workflows:**
- Feature branch workflow
- Fork and pull request model
- Centralized workflow

## Phase 5: Advanced Concepts (1-2 weeks)

### 9. Rewriting History
**Reading:** [Pro Git - Chapter 7: Git Tools](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)

**Commands to master:**
```bash
# Safe history rewriting
git commit --amend         # Fix last commit
git rebase -i HEAD~3       # Interactive rebase
git rebase --continue      # Continue after conflict
git rebase --abort         # Cancel rebase

# Reset vs revert
git reset --soft HEAD~1    # Unstage last commit
git reset --hard HEAD~1    # Discard last commit
git revert HEAD            # Create opposite commit
```

### 10. Advanced Merging
**Reading:** [Pro Git - Advanced Merging](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging)

**Techniques:**
```bash
git merge --no-ff <branch> # No fast-forward merge
git cherry-pick <commit>   # Apply specific commit
git stash                   # Temporarily save changes
git stash pop              # Restore stashed changes
```

## Phase 6: Daily Workflow Mastery (1 week)

### 11. Efficient Daily Commands
**Reading:** [Atlassian Git Cheatsheet](https://www.atlassian.com/git/tutorials/atlassian-git-cheatsheet)

**Time-saving aliases:**
```bash
# Useful aliases to add to ~/.gitconfig
[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  unstage = reset HEAD --
  last = log -1 HEAD
  visual = !gitk
```

### 12. Git Hooks and Automation
**Reading:** [Pro Git - Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

**Common hooks:**
- pre-commit: Run linting/tests
- commit-msg: Enforce commit message format
- pre-push: Run full test suite

## Phase 7: Troubleshooting and Best Practices (ongoing)

### 13. Common Problems and Solutions
**Reading:** [Git Flight Rules](https://github.com/k88hudson/git-flight-rules)

**Essential rescue commands:**
```bash
# Undo almost anything
git reflog                  # Show all changes
git reset --hard <commit>   # Restore to any state
git checkout -- <file>      # Discard file changes
git clean -fd               # Remove untracked files

# Find problematic commits
git bisect start            # Binary search for bugs
git bisect bad              # Mark current as bad
git bisect good <commit>    # Mark known good commit
```

### 14. Performance and Large Repositories
**Reading:** [Git LFS Documentation](https://git-lfs.github.com/)

**Optimization techniques:**
```bash
# Repository maintenance
git gc                      # Garbage collection
git fsck                    # Check integrity
git prune                   # Remove unreachable objects
```

## Phase 8: Specialized Topics (as needed)

### 15. Submodules and Subtrees
**Reading:** [Pro Git - Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

### 16. Git Internals
**Reading:** [Pro Git - Chapter 9: Git Internals](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)

## Recommended Learning Path

### Week 1: Foundation
- Days 1-2: Phase 1 (Basics)
- Days 3-5: Phase 2 (Core workflow)
- Days 6-7: Phase 3 (Branching basics)

### Week 2: Collaboration
- Days 1-2: Phase 4 (Remotes)
- Days 3-4: Practice collaborative workflow
- Days 5-7: Phase 5 (Advanced concepts intro)

### Week 3: Advanced Skills
- Days 1-3: Phase 5 (History rewriting)
- Days 4-5: Phase 6 (Daily workflow)
- Days 6-7: Phase 7 (Troubleshooting)

### Ongoing: Specialization
- Phase 8 topics as needed
- Regular practice with real projects

## Practice Projects

### Beginner Projects
1. **Personal website**: Track changes to HTML/CSS files
2. **Configuration files**: Version control dotfiles
3. **Writing projects**: Track essays or documentation

### Intermediate Projects
1. **Open source contribution**: Fork and submit pull requests
2. **Team project**: Collaborate with others
3. **Multi-branch feature**: Develop features in isolation

### Advanced Projects
1. **Large repository**: Handle binary files with Git LFS
2. **Monorepo management**: Use submodules or subtrees
3. **CI/CD integration**: Set up automated workflows

## Additional Resources

### Interactive Learning
- [Learn Git Branching](https://learngitbranching.js.org/) - Interactive visualization
- [GitHub Learning Lab](https://lab.github.com/) - Hands-on courses
- [GitKraken Git GUI](https://www.gitkraken.com/) - Visual learning tool

### Reference Materials
- [Git Reference Manual](https://git-scm.com/docs)
- [Git Cheat Sheets](https://education.github.com/git-cheat-sheet-education.pdf)
- [Pro Git Book](https://git-scm.com/book) (Free online)

### Community and Support
- [Stack Overflow Git Tag](https://stackoverflow.com/questions/tagged/git)
- [Git Subreddit](https://www.reddit.com/r/git/)
- [GitHub Community Forum](https://github.community/)

## Mastery Checklist

- [ ] Can explain Git's three states
- [ ] Comfortable with basic add/commit/push workflow
- [ ] Can create and merge branches confidently
- [ ] Understands and can resolve merge conflicts
- [ ] Can use rebase for history cleanup
- [ ] Knows when to use merge vs rebase
- [ ] Can recover from common mistakes
- [ ] Understands remote workflows
- [ ] Can set up and use Git hooks
- [ ] Familiar with Git internals basics

Remember: Git mastery comes from practice. Use it daily, make mistakes, and learn from them!