package user

import (
	"errors"
	"strconv"
)

var (
	ErrInvalidName  = errors.New("invalid name: must be between 1 and 30 characters")
	ErrInvalidAge   = errors.New("invalid age: must be between 0 and 150")
	ErrInvalidEmail = errors.New("invalid email format")
)

type User struct {
	Name  string
	Age   int
	Email string
}

func (u *User) Validate() error {
	if !IsValidName(u.Name) {
		return ErrInvalidName
	}
	if !IsValidAge(u.Age) {
		return ErrInvalidAge
	}
	if !IsValidEmail(u.Email) {
		return ErrInvalidEmail
	}
	return nil
}

func (u *User) String() string {
	return "Name: " + u.Name +
		", Age: " + strconv.Itoa(u.Age) +
		", Email: " + u.Email
}

func NewUser(name string, age int, email string) (*User, error) {
	u := &User{
		Name:  name,
		Age:   age,
		Email: email,
	}
	if err := u.Validate(); err != nil {
		return nil, err
	}
	return u, nil
}

func IsValidEmail(email string) bool {
	at := -1
	for i := 0; i < len(email); i++ {
		if email[i] == '@' {
			if at != -1 {
				return false
			}
			at = i
		}
	}
	if at <= 0 || at >= len(email)-1 {
		return false
	}
	for i := at + 1; i < len(email); i++ {
		if email[i] == '.' {
			return true
		}
	}
	return false
}

func IsValidName(name string) bool {
	return len(name) > 0 && len(name) <= 30
}

func IsValidAge(age int) bool {
	return age >= 0 && age <= 150
}
