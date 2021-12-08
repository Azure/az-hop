variable CreatedBy {
  default = ""
}

variable tenant_id {
  type = string
  description = "The azure tenant id the user is logged in"
  default = ""
}

variable logged_user_objectId {
  type = string
  description = "The azure user logged object id"
  default = ""
}