locals {
  policy_arns = flatten([
    for repo_key, repo in var.github_oidc_repositories : [
      for policy_arn in repo.policy_arns : {
        repo       = repo_key
        policy_arn = policy_arn
        policy_key = "${repo_key}${index(repo.policy_arns, policy_arn)}" # Adding an artificial key to prevent issues with duplicate keys in for_each when multiple ARNs are in the list.
      }
    ]
  ])
}