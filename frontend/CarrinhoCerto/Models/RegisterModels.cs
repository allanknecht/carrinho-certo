using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CarrinhoCerto.Models
{
    internal class RegisterModels
    {
    }

    public class RegisterRequest
    {
        public string email { get; set; }
        public string password { get; set; }
    }

    public class RegisterErrorResponse
    {
        public List<string> errors { get; set; }
    }
}
