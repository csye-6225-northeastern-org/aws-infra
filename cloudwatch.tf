resource "aws_cloudwatch_log_group" "csye" { 
  name = "csye6225" 
} 

resource "aws_cloudwatch_log_stream" "webapp" { 
  name = "webapp" 
  log_group_name = aws_cloudwatch_log_group.csye.name 
}